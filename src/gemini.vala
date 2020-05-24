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
	SUCCESS = 20,
	TEMPORARY_REDIRECT = 30,
	PERMANENT_REDIRECT = 31,
	NOT_FOUND = 51,
}

public errordomain GeminiError {
	UNKNOWN_RESPONSE_CODE,
	INVALID_REQUEST,
	NOT_UTF8,
}

public errordomain GeminiCase {
	TEMPORARY_REDIRECT,
	PERMANENT_REDIRECT,
	NOT_FOUND,
}

public struct GeminiResponse {
	GeminiCode code;
	string meta;
	ssize_t len;
	uint8 contents[65535];
}

public struct Content {
	string meta;
	string text;
}

async GeminiResponse send_request (string uri) throws Error, IOError {
	var client = new SocketClient ();
	client.set_tls(true);
	client.set_tls_validation_flags(0);

	var conn = yield client.connect_to_uri_async (uri, 1965);

	conn.socket.set_blocking(true);
	size_t size;
	yield conn.output_stream.write_all_async ("%s\r\n".printf(uri).data, 0, null, out size);

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

public async Content get_gemini (string uri) throws Error {
	var response = yield send_request (uri);

	Content ret = {};
	ret.meta = response.meta;

	switch (response.code) {
	case SUCCESS:
		ret.text = (string) response.contents;
		if (!ret.text.validate ())
			throw new GeminiError.NOT_UTF8("not valid UTF-8");

		return ret;
	case TEMPORARY_REDIRECT:
		throw new GeminiCase.TEMPORARY_REDIRECT(ret.meta);
	case PERMANENT_REDIRECT:
		throw new GeminiCase.PERMANENT_REDIRECT(ret.meta);
	case NOT_FOUND:
		throw new GeminiCase.NOT_FOUND(ret.meta);
	default:
		throw new GeminiError.UNKNOWN_RESPONSE_CODE("unknown response code %d".printf(response.code));
	}
}
