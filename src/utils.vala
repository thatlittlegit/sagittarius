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

	public string ensure_utf8 (string charset, string text) throws ConvertError {
		if (text.length == 0) {
			return text;
		}

		if (charset == null || charset == "utf-8") {
			if (text.validate(text.length)) {
				return text;
			}

			throw new ConvertError.ILLEGAL_SEQUENCE("text claims to be UTF-8, but isnt?");
		}

		return convert(text, text.length, "utf-8", charset);
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

	public string[] array_plus (string[] arr, string val) {
		var output = new Array<string>.sized (true, true, sizeof (string), arr.length + 1);

		foreach (var i in arr) {
			output.append_val(i);
		}
		output.append_val(val);

		return output.data;
	}

	public string[] array_sans (string[] arr, string val) {
		var output = new Array<string>.sized (true, true, sizeof (string), arr.length - 1);

		foreach (var i in arr) {
			if (i != val) {
				output.append_val(i);
			}
		}

		return output.data;
	}

	public Action create_action (string name, ActionCallback cb) {
		var action = new SimpleAction(name, null);
		action.activate.connect(() => cb ());
		return action;
	}

	public delegate void ActionCallback ();

	public class ConfigurationEntry : Gtk.ListBoxRow {
		public string text { get; construct; }

		public signal void deleted (Gtk.Widget widget);

		public ConfigurationEntry (string text) {
			Object(text: text);
		}

		construct {
			var boxchild = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			var label = new Gtk.Label(text);
			var delbtn = new Gtk.Button.from_icon_name("list-remove-symbolic");
			delbtn.relief = Gtk.ReliefStyle.NONE;

			label.halign = Gtk.Align.START;
			label.margin_start = 8;
			label.ellipsize = Pango.EllipsizeMode.END;

			boxchild.pack_start(label, true, true);
			boxchild.pack_end(delbtn, false, false);
			add(boxchild);
			show_all ();
			hide (); // consistency TODO GTK4

			delbtn.clicked.connect(() => {
				deleted(this);
			});
		}
	}
}
