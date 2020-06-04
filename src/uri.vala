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

[CCode(cname ="uri_to_string_C")]
extern bool __uri_to_string__ (Uri orig, out string done) throws UriError;

[CCode(cname ="SUriError")]
public errordomain UriError {
	INVALID_ORIG,
	INVALID_NEW,
	FAILED_JOIN,
	COULDNT_CALCULATE_SIZE,
	MALLOC_FAIL,
	TOSTRING_FAIL,
}

[CCode]
public struct Uri {
	string scheme;
	string userinfo;
	string host;
	uint16 port;
	unowned List<string> ? path;
	string query;
	string fragment;
}

string quick_fix_uri (string uri) {
	if (uri.has_prefix("about:") && !uri.has_prefix("about://")) {
		return uri.replace("about:", "about://");
	}

	return uri;
}

public string parse_uri (string orig, string relative) throws UriError {
	string output = "";
	__parse_uri__(orig, quick_fix_uri(relative), out output);
	return output;
}

public Uri uri_struct (string uri) throws UriError {
	Uri ret;
	__parse_uri_struct__(quick_fix_uri(uri), out ret);
	return ret;
}

public string uri_with_query (string orig, string query) throws UriError {
	string output = "";
	__uri_with_query__(quick_fix_uri(orig), query, out output);
	return output;
}

public string uri_to_string (Uri uristruct) {
	try {
		string output = "";
		__uri_to_string__(uristruct, out output);
		return output;
	} catch (UriError err) {
		critical("uri_to_string failed?!? this is supposed to be impossible");
		return "";
	}
}
