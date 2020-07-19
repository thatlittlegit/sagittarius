/* render-welcome.vala
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

namespace Sagittarius.WelcomeRenderer {
	public class WelcomeRenderer : Object, Peas.Activatable, Renderer {
		public Object object { owned get; construct; }
		public Renderer welcome_renderer;

		[CCode(cname = "peas_register_types")]
		public static void peas_register_types (Peas.ObjectModule module) {
			module.register_extension_type(
				PEAS_TYPE_ACTIVATABLE,
				new WelcomeRenderer ().get_type ()
				);
		}

		public void activate () {
			add_renderer("application/x-sagittarius-welcome", this);
		}

		public void deactivate () {
			remove_renderer("application/x-sagittarius-welcome", this);
		}

		public void update_state () {
		}

		public async RenderingOutcome render (NavigateFunc ? nav, Content content) {
			var widget = new Dazzle.EmptyState ();
			widget.title = _("Welcome to Sagittarius!");
			widget.subtitle = _("Start by typing a URL in the address bar.");
			return { (string) Bytes.unref_to_data(content.data), widget };
		}
	}
}
