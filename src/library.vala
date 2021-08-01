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
	[GtkTemplate(ui = "/tk/thatlittlegit/sagittarius/library.ui")]
	internal class LibraryWindow : Gtk.Window {
		public ListStore history { private get; construct; }
		public File history_file { private get; construct; }
		public ListStore bookmarks { private get; construct; }
		public File bookmarks_file { private get; construct; }

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

		public LibraryWindow (ListStore history, File history_file,
							  ListStore bookmarks, File bookmarks_file) {
			Object(history: history, history_file: history_file,
				bookmarks: bookmarks, bookmarks_file: bookmarks_file);
		}

		construct {
			history_listbox = new UriListBox(history, history_file);
			listbox_stack.add_titled(history_listbox, "history", _("History"));
			history_listbox.selection_changed.connect(selection_changed_handler);
			history_listbox.show ();

			bookmarks_listbox = new UriListBox(bookmarks, bookmarks_file);
			listbox_stack.add_titled(bookmarks_listbox, "bookmarks", _(
				"Bookmarks"));
			bookmarks_listbox.selection_changed.connect(
				selection_changed_handler);
			bookmarks_listbox.show ();
		}

		private void selection_changed_handler (Gtk.ListBoxRow ? selected_row) {
			if (selected_row == null) {
				info_grid.sensitive = false;
				entry_title.label = "";
				uri.text = "";
				visited_date.label = "";
				return;
			}

			var entry = (HistoryEntry) history.get_item(selected_row.get_index ());
			info_grid.sensitive = true;
			entry_title.label = entry.title;
			uri.text = entry.uri.to_string ();
			visited_date.label = entry.date.format("%x %X%:z");
		}
	}

	private class UriListBox : Gtk.ListBox {
		public ListStore list { private get; construct; }
		public File file { private get; construct; }

		public UriListBox (ListStore list, File file) {
			Object(list: list, file: file);
		}

		construct {
			bind_model(list, (obj) => create_widget((HistoryEntry) obj));

			row_selected.connect(() => {
				selection_changed(get_selected_row ());
			});
		}

		public Gtk.Widget create_widget (HistoryEntry entry) {
			var widget = new ConfigurationEntry(entry.uri.to_string ());
			var container = new Gtk.ListBoxRow ();
			container.add(widget);

			widget.deleted.connect((widget) => {
				list.remove(container.get_index ());
				History.write_out_all(list, file);
			});

			container.show_all ();
			container.hide ();
			return container;
		}

		public signal void selection_changed (Gtk.ListBoxRow ? selected_row);
	}
}
