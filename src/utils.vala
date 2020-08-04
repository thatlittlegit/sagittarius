/* bytes-utils.vala
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
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Sagittarius {
	public string bytes_to_string (Bytes bytes) {
		if (bytes.length == 0) {
			return "";
		}

		var builder = new StringBuilder.sized(bytes.length);
		var data = Bytes.unref_to_data(bytes);
		builder.append_len((string) data, data.length);
		return builder.str;
	}

	public InputStream ensure_utf8 (GMime.ContentType type,
		InputStream content) throws IOError, ConvertError {
		if (type.type != "text") {
			return content;
		}

		var text = bytes_to_string(ByteArray.free_to_bytes(slurp(content)));

		if (text.length == 0) {
			return new MemoryInputStream.from_data(text.data);
		}

		var charset = type.get_parameter("charset");
		if (charset == null || charset == "utf-8") {
			if (text.validate(text.length)) {
				return new MemoryInputStream.from_data(text.data);
			}

			throw new ConvertError.ILLEGAL_SEQUENCE(
				"text claims to be UTF-8, but isnt?");
		}

		return new MemoryInputStream.from_bytes(
			new Bytes.take(convert(text, text.length, "utf-8", charset).data));
	}

	public ByteArray slurp (InputStream data) throws IOError {
		var bytearray = new ByteArray ();
		while (true) {
			Bytes chunk;

			try {
				chunk = data.read_bytes(65535);
			} catch (Error err) {
				throw new IOError.FAILED("(%p) %s", (void *) err, err.message);
			}

			if (chunk.length == 0) {
				break;
			}

			bytearray.append(Bytes.unref_to_data(chunk));
		}

		return bytearray;
	}

	public class FeebleRef<T> {
		private WeakRef<T> wr;

		public FeebleRef (T obj) {
			wr = WeakRef((Object) obj);
		}

		public T ? @get () {
			return (T ? ) wr.@get ();
		}
	}

	public class Wrapped<T>: Object {
		private T wrapped;

		public Wrapped (T subject) {
			wrapped = subject;
		}

		// *rust flashbacks*
		public T unwrap () {
			return wrapped;
		}

		public void replace (T subject) {
			wrapped = subject;
		}
	}
}
