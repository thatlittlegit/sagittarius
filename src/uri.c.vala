/* uri.c.vala
 *
 * Copyright 2020 thatlittlegit <personal@thatlittlegit.tk>
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
 *
 */

[CCode(cname ="parse_uri_C")]
extern bool __parse_uri__ (string orig_uri, string new_uri, out string created) throws UriError;

[CCode(cname ="parse_uri_to_struct_C")]
extern bool __parse_uri_struct__ (string uri, out Uri transformed) throws UriError;

[CCode(cname ="uri_with_query_C")]
extern bool __uri_with_query__ (string orig, string query, out string done) throws UriError;

[CCode(cname ="SUriError")]
public errordomain UriError {
	INVALID_ORIG,
	INVALID_NEW,
	FAILED_JOIN,
	COULDNT_CALCULATE_SIZE,
	MALLOC_FAIL,
	TOSTRING_FAIL,
}

public struct Uri {
	string scheme;
}

public string parse_uri (string orig, string relative) throws UriError {
	string output = "";
	__parse_uri__(orig, relative, out output);
	return output;
}

public Uri uri_struct (string uri) throws UriError {
	Uri ret;
	__parse_uri_struct__(uri, out ret);
	return ret;
}

public string uri_with_query (string orig, string query) throws UriError {
	string output = "";
	__uri_with_query__(orig, query, out output);
	return output;
}
