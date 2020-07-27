/* evince-view-3.0.vapi
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

[CCode (cprefix = "Ev", lower_case_cprefix = "ev_")]
namespace Evince {
	[CCode(cname = "EvView", cheader_filename = "evince-view.h")]
	public class View : Gtk.Container {
		public View();
		public void set_model(DocumentModel model);
	}

	[CCode(cname = "EvDocumentModel", cheader_filename = "evince-view.h")]
	public class DocumentModel : GLib.Object {
		public DocumentModel.with_document(Evince.Document document);
	}
}
