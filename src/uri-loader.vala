/* uri-loader.vala
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

namespace Sagittarius {
	public interface UriLoader : Object {
		public abstract async Content fetch (Upg.Uri uri);
	}

	public struct Content {
		Upg.Uri original_uri;
		GMime.ContentType content_type;
		Bytes data;
	}

	HashTable<string, UriLoader> loaders = null;

	public void init_loaders () {
		if (loaders == null)
			loaders = new HashTable<string, UriLoader>(str_hash, str_equal);
	}

	public void add_loader (string scheme, UriLoader impl) {
		loaders.insert(scheme, impl);
	}

	public void remove_loader (string scheme, UriLoader impl) {
		// FIXME impl should eventually be used to only remove the right one
		loaders.remove(scheme);
	}

	async Content open_with_glib (Upg.Uri uri) {
		AppInfo.launch_default_for_uri_async.begin(uri.to_string (), null);

		var content = new Bytes("# URI not recognized.\nYou should've been prompted for where to open it.".data);
		return {
				   uri,
				   new GMime.ContentType("text", "gemini"),
				   content,
		};
	}

	public async Content fetch_uri (Upg.Uri uri) throws Error {
		if (uri.scheme == "gemini") {
			return yield get_gemini (uri);
		}

		var loader = loaders.lookup(uri.scheme);
		if (loader != null) {
			return yield loader.fetch (uri);
		}

		return yield open_with_glib (uri);
	}

	public Content ensure_utf8 (Content content) throws ConvertError {
		if (content.content_type.type != "text") {
			return content;
		}

		var text = (string) Bytes.unref_to_data(content.data);

		var charset = content.content_type.get_parameter("charset");
		if (charset == null || charset == "utf-8") {
			if (text.validate(text.length)) {
				return content;
			}

			throw new ConvertError.ILLEGAL_SEQUENCE("text claims to be UTF-8, but isnt?");
		}

		content.data = new Bytes.take(convert(text, text.length, "utf-8", charset).data);
		return content;
	}
}
