/* library.vala
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

			bookmarks_listbox = new UriListBox(bookmarks, bookmarks_file);
			listbox_stack.add_titled(bookmarks_listbox, "bookmarks", _(
				"Bookmarks"));
			bookmarks_listbox.selection_changed.connect(
				selection_changed_handler);
		}

		private void selection_changed_handler (Gtk.ListBoxRow ? selected_row) {
			if (selected_row == null) {
				info_grid.sensitive = false;
				entry_title.label = "";
				uri.text = "";
				visited_date.label = "";
				return;
			}

			var entry = (HistoryEntry) history.get_item(selected_row.get_data<int>(
				"entry"));
			info_grid.sensitive = true;
			entry_title.label = entry.title;
			uri.text = entry.uri.to_string_ign(
				Upg.UriFatalRanking.NONFATAL_NULLABLE);
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
			row_selected.connect(() => {
				selection_changed(get_selected_row ());
			});
			update ();

			list.items_changed.connect(() => update ());
		}

		public void update () {
			foreach (var child in get_children ()) {
				remove(child);
			}

			for (var i = int.max((int) list.get_n_items () - 100, 0);
				 i < list.get_n_items (); i++) {
				var entry = (HistoryEntry) list.get_item(i);

				var widget =
					new ConfigurationEntry(entry.uri.to_string_ign(Upg.
						 UriFatalRanking
						 .NONFATAL_NEVERNULL));

				var _entry = entry;
				widget.set_data<int>("entry", i);

				widget.deleted.connect((widget) => {
					list.remove(widget.get_data<int>("entry"));
					History.write_out_all(list, file);
					update ();
				});

				add(widget);
				((MainContext) null).iteration(false);
			}

			show_all ();
			selection_changed(get_selected_row ());
		}

		public signal void selection_changed (Gtk.ListBoxRow ? selected_row);
	}
}
