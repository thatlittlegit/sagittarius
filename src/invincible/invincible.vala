/* invincible.vala
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

using Sagittarius;

namespace Sagittarius.Invincible {
	public class InvinciblePlugin : Plugin, Renderer {
		[CCode(cname = "peas_register_types")]
		public static void peas_register_types (Peas.ObjectModule module) {
			module.register_extension_type(
				typeof (Plugin),
				typeof (InvinciblePlugin)
				);
		}

		public override void activate () {
			Evince.init ();
		}

		public override void deactivate () {
			Evince.shutdown ();
		}

		public async Gtk.Widget render (NavigateFunc ? nav, Content content, Cancellable ? cancel,
			LoadingTrigger ? trigger) throws Error {
			// FIXME this should have been the easiest to do, but the stream
			//       has to be seekable
			var stream =
				new MemoryInputStream.from_bytes(ByteArray.free_to_bytes(slurp(
					content.data)));
			var document = Evince.DocumentFactory.get_document_for_stream(
				stream, content.content_type.to_simple_string ());

			var view = new Evince.View ();
			view.set_model(new Evince.DocumentModel.with_document(document));
			trigger.trigger(document.get_title ());
			return view;
		}
	}
}
