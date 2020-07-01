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
}

public struct GeminiResponse {
	GeminiCode code;
	string meta;
	ssize_t len;
	uint8 contents[65535];
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
	var stream = new DataInputStream(conn.input_stream);

	string response_header = yield stream.read_line_utf8_async ();

	info("response header is '%s'".printf(response_header));
	response_header.scanf("%d", &response.code);
	response.meta = response_header.substring(3, response_header.length - 3).strip ();


	// XXX OH GOD THIS IS HORRIBLE
	// this code is here because this read_async call didn't seem to work for
	// me:
	//     response.len = yield conn.input_stream.read_async(response.contents);
	// this is INCREDIBLY inefficient, if you know anything about GIO consider
	// helping please
	for (response.len = 0; response.len < 65535; response.len++) {
		try {
			response.contents[response.len] = stream.read_byte ();
		} catch (Error err) {
			break;
		}
	}
	info("recieved %ld bytes".printf(response.len));

	return response;
}

public async Sagittarius.Content get_gemini (Upg.Uri uri) throws Error {
	var response = yield send_request (uri);

	Sagittarius.Content ret = {};
	ret.content_type = GMime.ContentType.parse(new GMime.ParserOptions (), response.meta);
	ret.code = response.code;
	ret.original_uri = uri;

	if (response.code == GeminiCode.SUCCESS) {
		if (ret.content_type.type == "text") {
			ret.text = (string) response.contents;

			if (!ret.text.validate ()) {
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
			ret.data = response.contents;
		}
	} else {
		ret.text = response.meta;
	}

	return ret;
}
