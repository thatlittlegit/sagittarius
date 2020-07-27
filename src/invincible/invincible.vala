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
		construct {
			add_renderer("application/pdf", this);
		}

		[CCode(cname = "peas_register_types")]
		public static void peas_register_types (Peas.ObjectModule module) {
			module.register_extension_type(
				PEAS_TYPE_ACTIVATABLE,
				new InvinciblePlugin ().get_type ()
				);
		}

		public override void activate () {
			Evince.init ();
		}

		public override void deactivate () {
			Evince.shutdown ();
		}

		public async RenderingOutcome render (HashTable<string,
														Object ? > state,
			NavigateFunc ? nav,
			Content content) {
			var stream = new MemoryInputStream.from_bytes(content.data);
			var document = Evince.DocumentFactory.get_document_for_stream(
				stream, content.content_type.get_mime_type ());

			var view = new Evince.View ();
			view.set_model(new Evince.DocumentModel.with_document(document));
			return { document.get_title (), view };
		}
	}
}
