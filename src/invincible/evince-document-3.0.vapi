/* evince.vapi
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

/* Evince doesn't seem to give us VAPI files, so this is a small shim for the
 * stuff that we need.
 */
[CCode (cprefix = "Ev", lower_case_cprefix = "ev_")]
namespace Evince {
	[CCode(cname = "ev_init")]
	public bool init();

	[CCode(cname = "ev_shutdown")]
	public void shutdown();

	[CCode(cname = "EvDocument", cheader_filename = "evince-document.h")]
	public abstract class Document : GLib.Object {
		public string get_title();
	}

	[CCode (lower_case_cprefix = "ev_document_factory_")]
	namespace DocumentFactory {
		public Evince.Document get_document_for_stream(GLib.InputStream stream, string mime, DocumentLoadFlags flags = 0, GLib.Cancellable? cancellable = null) throws GLib.Error;
	}

	[CCode(cname = "EvDocumentLoadFlags")]
	public enum DocumentLoadFlags {
		NONE = 0,
		NO_CACHE = 1,
	}
}
