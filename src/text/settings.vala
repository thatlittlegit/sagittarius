/* settings.vala
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

namespace Sagittarius.Text {
	private class MimeRow : Gtk.ListBoxRow {
		public string mime_type { get; set construct; }

		public signal void deleted ();

		public MimeRow (string val) {
			Object(mime_type: val);
		}

		construct {
			var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);

			var label = new Gtk.Label(mime_type);
			box.pack_start(label, true, true);

			var button = new Gtk.Button.from_icon_name("list-remove-symbolic");
			button.relief = Gtk.ReliefStyle.NONE;
			box.pack_end(button, false);

			this.bind_property("mime_type", label, "label",
				BindingFlags.BIDIRECTIONAL);
			button.clicked.connect(() => deleted ());

			add(box);
			show_all ();

			// for consistency
			hide (); // TODO gtk4: remove
		}
	}

	[GtkTemplate(ui = "/tk/thatlittlegit/sagittarius/text/settings.ui")]
	internal class Settings : Gtk.Bin {
		public TextPlugin plugin { private get; construct set; }

		[CCode(array_null_terminated = true, array_length = true)]
		public string[] mime_types { get; set; }
		[GtkChild]
		private Gtk.ListBox listbox;
		[GtkChild]
		private Gtk.Entry add_entry;

		internal Settings (TextPlugin plugin) {
			Object(plugin: plugin);
		}

		construct {
			var settings =
				new GLib.Settings("tk.thatlittlegit.sagittarius.text");

			settings.bind_with_mapping("mime-types", this, "mime_types",
				SettingsBindFlags.DEFAULT,
				bind_mime_types_getfunc,
				bind_mime_types_setfunc, null, null);

			this.notify.connect((spec) => {
				if (spec.get_name () != "mime-types") {
					return;
				}

				remove_all_renderers_of_type(typeof (TextPlugin));

				listbox.foreach ((child) => {
					listbox.remove(child);
				});

				for (int i = 0; i < mime_types.length; i++) {
					if (mime_types[i] == "") {
						continue;
					}

					add_renderer(mime_types[i], plugin);

					var label = new MimeRow(mime_types[i]);
					label.set_data<int>("i", i);
					label.deleted.connect(() => {
						mime_types[label.get_data<int>("i")] = "";
						notify_property("mime-types");
					});

					label.show ();
					listbox.add(label);
				}
			});
		}

		private static bool bind_mime_types_getfunc (Value val, Variant variant,
			void * _) {
			val.take_boxed(variant.dup_strv ());
			return true;
		}

		private static Variant bind_mime_types_setfunc (Value val,
			VariantType variant,
			void * _) {
			return new Variant.strv((string[]) val.get_boxed ());
		}

		[GtkCallback]
		private void add_cb () {
			freeze_notify ();
			var res = new string[mime_types.length + 1];
			for (int i = 0; i < mime_types.length; i++) {
				res[i] = mime_types[i];
			}
			res[mime_types.length] = add_entry.text;
			mime_types = res;
			thaw_notify ();
			add_entry.text = "";
		}
	}
}
