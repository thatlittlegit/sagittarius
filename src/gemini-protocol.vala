/* gemini.vala
 *
 * Copyright 2020 thatlittlegit
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
public enum GeminiCode {
	INPUT = 10,
	SUCCESS = 20,
	// END_OF_SESSION = 21,
	TEMPORARY_REDIRECT = 30,
	PERMANENT_REDIRECT = 31,
	TEMPORARY_ERROR = 40,
	SERVER_UNAVAILABLE = 41,
	CGI_ERROR = 42,
	PROXY_ERROR = 43,
	SLOW_DOWN = 44,
	PERMANENT_ERROR = 50,
	NOT_FOUND = 51,
	GONE = 52,
	PROXY_REQUEST_REFUSED = 53,
	BAD_REQUEST = 59,
	// CLIENT_CERTIFICATE_REQUIRED = 60,
	// TRANSIENT_CERTIFICATE_REQUIRED = 61,
	// AUTHORIZED_CERTIFICATE_REQUIRED = 62,
	// INVALID_CERTIFICATE = 63,
	// CERTIFICATE_FROM_FUTURE = 64,
	// THAT_CERT_IS_OLDER_THAN_I_AM = 65,
}

public errordomain GeminiError {
	UNKNOWN_RESPONSE_CODE,
	INVALID_REQUEST,
	INVALID_ENCODING,
	INVALID_RESPONSE,
}

public struct GeminiResponse {
	GeminiCode code;
	string meta;
	Bytes contents;
}


async GeminiResponse send_request (Upg.Uri uri) throws Error, IOError {
	var client = new SocketClient ();
	client.set_tls(true);
	client.set_tls_validation_flags(0);

	var struri = uri.to_string ();
	var conn = yield client.connect_to_uri_async (struri, 1965);

	conn.socket.set_blocking(true);
	size_t size;
	yield conn.output_stream.write_all_async ("%s\r\n".printf(struri).data, 0, null, out size);

	info("sent request [%ld bytes]".printf((ssize_t) size));

	GeminiResponse response = {};

	var bytearray = new ByteArray ();
	while (true) {
		Bytes chunk;
		try {
			chunk = yield conn.input_stream.read_bytes_async (65535);
		} catch (TlsError err) {
			if (err.code != 6) {
				throw err;
			}
			chunk = new Bytes({});
		}

		if (chunk.length == 0) {
			break;
		}

		bytearray.append(Bytes.unref_to_data(chunk));
	}
	;
	yield conn.close_async ();

	if (bytearray.len < 2) {
		throw new GeminiError.INVALID_RESPONSE("Invalid response (too small)");
	}

	response.code = ((bytearray.data[0] - 0x30) * 10)
					+ (bytearray.data[1] - 0x30);
	bytearray.remove_range(0, 2);

	int i;
	StringBuilder meta = new StringBuilder.sized(bytearray.len.clamp(0, 1024));
	for (i = 0; i < bytearray.len && i < 1024; i++) {
		char current = (char) bytearray.data[i];

		if (current == '\r') {
			i++;
			break;
		}

		if (current == '\n') {
			// invalid, but we'll let it slide 'cause it's a lot better
			break;
		}

		meta.append_c(current);
	}
	response.meta = meta.str.strip ();
	bytearray.remove_range(0, i);
	message("%s", response.meta);

	response.contents = ByteArray.free_to_bytes(bytearray);
	info("recieved %ld bytes of content".printf(response.contents.length));

	return response;
}

public async Sagittarius.Content get_gemini (Upg.Uri uri) throws Error {
	var response = yield send_request (uri);

	Sagittarius.Content ret = {};
	ret.content_type = GMime.ContentType.parse(new GMime.ParserOptions (), response.meta);
	ret.code = response.code;
	ret.original_uri = uri;

	uint8[] data = Bytes.unref_to_data(response.contents);

	if (response.code == GeminiCode.SUCCESS) {
		if (ret.content_type.type == "text") {
			ret.text = (string) data;

			if (!ret.text.validate(data.length)) {
				try {
					var charset = ret.content_type.get_parameter("charset");
					if (charset == null || charset == "utf-8") {
						throw new GeminiError.INVALID_ENCODING("text claims to be UTF-8, but isnt?");
					} else {
						ret.text = convert(ret.text, -1, "utf-8", ret.content_type.get_parameter("charset"));
					}
				} catch (ConvertError err) {
					warning("ConvertError while converting contents (%s)".printf(err.message));
					throw new GeminiError.INVALID_ENCODING("not valid text, apparently");
				}
			}
		} else {
			ret.data = data;
		}
	} else {
		ret.text = response.meta;
	}

	return ret;
}
