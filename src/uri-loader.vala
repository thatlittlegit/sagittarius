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
		public abstract async Content fetch (HashTable<string, Object ? > state,
			Upg.Uri uri) throws Error;
	}

	public struct Content {
		UriLoadOutcome outcome;
		Upg.Uri original_uri;
		ContentType content_type;
		InputStream data;
		IOStream ? __holder;
	}

	public enum UriLoadOutcome {
		TEXT_INPUT_WANTED = 10,
		SUCCESS = 20,
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
		UNKNOWN_SCHEME = 100,
	}

	HashTable<string, FeebleRef<UriLoader> > loaders = null;

	internal void init_loaders () {
		if (loaders == null)
			loaders = new HashTable<string, FeebleRef<UriLoader> ? >(str_hash,
				str_equal);
	}

	public void add_loader (string scheme, UriLoader impl) {
		loaders.replace(scheme, new FeebleRef<UriLoader>(impl));
	}

	public void remove_loader (string scheme, UriLoader impl) {
		// FIXME impl should eventually be used to only remove the right one
		loaders.remove(scheme);
	}

	public void remove_all_loaders_of_type (Type type) {
		loaders.foreach_remove((entry) => {
			var obj = loaders.lookup(entry).@get ();
			return obj == null || obj.get_type () == type;
		});
	}

	public async Content fetch_uri (HashTable<string, Object ? > state,
		Upg.Uri uri) throws Error {
		var loader = loaders.lookup(uri.scheme);
		if (loader != null && loader.@get () != null) {
			return yield loader.@get ().fetch(state, uri);
		}

		return { UriLoadOutcome.UNKNOWN_SCHEME, uri, null,
				 new MemoryInputStream.from_data({}) };
	}
}
