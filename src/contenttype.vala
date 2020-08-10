/* contenttype.vala
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
	public class ContentType : Object {
		public string primary { get; construct set; }
		public string subtype { get; construct set; }

		public HashTable<string, string> properties { get; construct; }

		public string ? charset {
			get {
				return properties.lookup("charset");
			}
		}

		construct {
			properties = new HashTable<string, string>(str_hash, str_equal);
		}

		public ContentType (string primary, string subtype) {
			Object(primary: primary, subtype: subtype);
		}

		private enum Mode {
			INITIAL = 0,
			TYPE = 0,
			SUBTYPE,
			PARAM_KEY,
			PARAM_VALUE,
		}

		public ContentType.parse(string str) {
			Object ();
			var mode = Mode.INITIAL;

			bool comment = false;
			bool quote = false;

			var primary_builder = new StringBuilder.sized(24);
			var subtype_builder = new StringBuilder.sized(24);
			var key_builder = new StringBuilder.sized(24);
			var value_builder = new StringBuilder.sized(24);

			foreach (char chr in (char[]) str.data) {
				if (chr == '(') {
					comment = true;
				}

				if (chr == ')') {
					comment = false;
				}

				if (comment || (!quote && chr.isspace ())) {
					continue;
				}

				switch (mode) {
				case TYPE:
					if (chr == '/') {
						primary = primary_builder.str;
						mode = Mode.SUBTYPE;
					} else {
						primary_builder.append_c(chr);
					}
					break;
				case SUBTYPE:
					if (chr == ';') {
						subtype = subtype_builder.str;
						mode = Mode.PARAM_KEY;
					} else {
						subtype_builder.append_c(chr);
					}
					break;
				case PARAM_KEY:
					if (chr == '=') {
						mode = Mode.PARAM_VALUE;
					} else {
						key_builder.append_c(chr);
					}
					break;
				case PARAM_VALUE:
					if (chr == ';') {
						properties.insert(key_builder.str, value_builder.str);
						mode = Mode.PARAM_KEY;
						key_builder.erase ();
						value_builder.erase ();
					} else if (chr == '"') {
						quote = !quote;
					} else {
						value_builder.append_c(chr);
					}
					break;
				default:
					error("unexpected mode in contenttype.parse");
				}
			}

			if (mode <= Mode.TYPE) {
				primary = "unknown";
			}

			if (mode <= Mode.SUBTYPE) {
				if (subtype_builder.len == 0) {
					subtype = "unknown";
				} else {
					subtype = subtype_builder.str;
				}
			}

			if (mode == PARAM_KEY && subtype_builder.len > 0) {
				properties.insert(key_builder.str, "");
			}

			if (mode == Mode.PARAM_VALUE) {
				properties.insert(key_builder.str, value_builder.str);
			}
		}

		public string to_simple_string () {
			return "%s/%s".printf(primary, subtype);
		}

		public string to_string () {
			var ret = new StringBuilder(to_simple_string ());
			var iter = HashTableIter<string, string>(properties);

			string name;
			string val;
			while (iter.next(out name, out val)) {
				ret.append("; ");
				ret.append(name);

				if (val != "") {
					ret.append_c('=');
					ret.append(val);
				}
			}

			return ret.str;
		}

		public bool matches (ContentType other) {
			if (primary != "*" && primary != other.primary) {
				return false;
			}

			if (subtype != "*" && subtype != other.subtype) {
				return false;
			}

			return true;
		}
	}
}
