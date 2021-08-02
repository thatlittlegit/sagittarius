/* library.vala
 *
 * Copyright 2020-2021 thatlittlegit <personal@thatlittlegit.tk>
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
	public class LibraryEntry : Object {
		public DateTime date;
		public Upg.Uri uri;
		public string title;

		public LibraryEntry (DateTime ? a, Upg.Uri b, string ? c) {
			date = a ?? new DateTime.from_unix_utc(0);
			uri = b;
			title = c ?? b.to_string ();
		}
	}

	public class Library : Object, AsyncInitable, ListModel {
		public File input_file { private get; construct set; }
		private IOStream stream;
		private List<LibraryEntry> entries;

		public Library (File input) {
			Object(input_file: input);
		}

		public async void init (int io_priority, Cancellable ? cancel) throws Error {
			stream = yield input_file.open_readwrite_async (io_priority, cancel);

			yield parse_file (stream);
		}

		private async void parse_file (IOStream istream) throws Error {
			var stream = new DataInputStream(istream.get_input_stream ());
			var original_length = entries.length ();
			entries = new List<LibraryEntry>();

			string line;
			while ((line = yield stream.read_line_utf8_async ()) != null) {
				if (line.strip () == "" || line.has_prefix("#")) {
					continue;
				}

				var parts = line.split("\t", 3);
				try {
					var date = new DateTime.from_iso8601(parts[0], null).to_local ();
					var uri = new Upg.Uri(parts[1]);
					var title = parts[2];

					var entry = new LibraryEntry(date, uri, title);
					entries.prepend(entry);
				} catch (Error err) {
					warning("failed to make LibraryEntry for %s: %s", parts[1], err.message);
				}
			}

			items_changed(0, original_length, entries.length ());
		}

		public async void write_output (int io_priority = Priority.DEFAULT, Cancellable ? cancel = null) throws Error {
			IOStream streams;
			var temp_file = File.new_tmp(null, out streams);

			foreach (var entry in entries) {
				// TODO after GLib 2.62 we can use format_iso8601
				var date = entry.date.to_utc ().format("%FT%TZ");
				var uri = entry.uri.to_string ();
				var title = entry.title;

				var line = "%s\t%s\t%s\n".printf(date, uri, title);
				size_t written;
				yield streams.get_output_stream ().write_all_async(line.data, io_priority, cancel, out written);
			}

			temp_file.move(input_file, FileCopyFlags.OVERWRITE, cancel);
		}

		public Type get_item_type () {
			return typeof (LibraryEntry);
		}

		public LibraryEntry ? get_entry(uint position) {
			return get_item(position) as LibraryEntry;
		}

		// Actually 'LibraryEntry?' but ListModel::get_item must return Object?.
		public Object ? get_item(uint position) {
			return entries.nth_data(position);
		}

		public void add_entry (LibraryEntry entry) {
			entries.prepend(entry);
			items_changed(0, 0, 1);
			write_output_internal ();
		}

		public void remove_entry (LibraryEntry entry) {
			unowned List<LibraryEntry> elem = entries.find(entry);
			var position = entries.position(elem);
			entries.remove_link(elem);
			items_changed(position, 1, 0);
			write_output_internal ();
		}

		private void write_output_internal () {
			write_output.begin(Priority.DEFAULT, null, (obj, res) => {
				try {
					write_output.end(res);
				} catch (Error err) {
					warning("failed to save history: %s", err.message);
				}
			});
		}

		public uint get_n_items () {
			return entries.length ();
		}
	}

	[GtkTemplate(ui = "/tk/thatlittlegit/sagittarius/library.ui")]
	internal class LibraryWindow : Gtk.Window {
		public Library history { private get; construct; }
		public Library bookmarks { private get; construct; }

		[GtkChild]
		private unowned Gtk.Stack listbox_stack;
		[GtkChild]
		private unowned Gtk.Grid info_grid;
		[GtkChild]
		private unowned Gtk.Label entry_title;
		[GtkChild]
		private unowned Gtk.Entry uri;
		[GtkChild]
		private unowned Gtk.Label visited_date;

		private UriListBox history_listbox;
		private UriListBox bookmarks_listbox;

		public LibraryWindow (Library history, Library bookmarks) {
			Object(history: history, bookmarks: bookmarks);
		}

		construct {
			history_listbox = new UriListBox(history);
			listbox_stack.add_titled(history_listbox, "history", _("History"));
			history_listbox.selection_changed.connect(selection_changed_handler);

			bookmarks_listbox = new UriListBox(bookmarks);
			listbox_stack.add_titled(bookmarks_listbox, "bookmarks", _("Bookmarks"));
			bookmarks_listbox.selection_changed.connect(selection_changed_handler);

			listbox_stack.visible_child = history_listbox;
			listbox_stack.show_all ();
		}

		private void selection_changed_handler (Gtk.ListBoxRow ? selected_row) {
			if (selected_row == null) {
				info_grid.sensitive = false;
				entry_title.label = "";
				uri.text = "";
				visited_date.label = "";
				return;
			}

			var entry = (LibraryEntry) history.get_item(selected_row.get_index ());
			info_grid.sensitive = true;
			entry_title.label = entry.title;
			uri.text = entry.uri.to_string ();
			visited_date.label = entry.date.format("%x %X");
		}
	}

	private class UriListBox : Gtk.ListBox {
		public Library library { private get; construct; }

		public UriListBox (Library library) {
			Object(library: library);
		}

		construct {
			bind_model(library, (obj) => create_widget((LibraryEntry) obj));

			row_selected.connect(() => {
				selection_changed(get_selected_row ());
			});
		}

		public Gtk.Widget create_widget (LibraryEntry entry) {
			var widget = new ConfigurationEntry(entry.uri.to_string ());
			var container = new Gtk.ListBoxRow ();
			container.add(widget);

			widget.deleted.connect((widget) => {
				library.remove_entry(entry);
			});

			container.show_all ();
			container.hide ();
			return container;
		}

		public signal void selection_changed (Gtk.ListBoxRow ? selected_row);
	}
}
