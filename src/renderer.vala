/* renderer.vala
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
	public struct RenderingOutcome {
		string ? title;
		Gtk.Widget widget;
	}

	public interface Renderer : Object {
		public abstract async RenderingOutcome render (NavigateFunc ? nav, Content content) throws Error;
	}

	HashTable<string, Renderer> renderers = null;

	public void init_renderers () {
		if (renderers == null) {
			renderers = new HashTable<string, Renderer>(str_hash, str_equal);
		}
	}

	public void add_renderer (string mime, Renderer renderer) {
		renderers.insert(mime, renderer);
	}

	public void remove_renderer (string mime, Renderer renderer) {
		// TODO only remove the right renderer
		renderers.remove(mime);
	}

	public async RenderingOutcome render_content (NavigateFunc nav, Content content) throws Error {
		var type = stringify_mime_type(content.content_type);

		if (type == "text/gemini") {
			var markup = yield parse_markup (content.original_uri, content.data);

			var widget = yield display_markup (markup, nav);

			RenderingOutcome ret = {};
			ret.title = markup.title ?? content.original_uri.to_string ();
			ret.widget = widget;
			return ret;
		}

		var renderer = renderers.lookup(type);
		if (renderer != null) {
			return yield renderer.render (nav, content);
		}

		return open_user_default(content);
	}

	string stringify_mime_type (GMime.ContentType type) {
		return "%s/%s".printf(type.type, type.subtype);
	}

	errordomain RenderingError {
		NO_MIME_TYPE,
	}

	RenderingOutcome open_user_default (Content content) throws Error {
		// TODO we need to support writing to a file first
		throw new RenderingError.NO_MIME_TYPE(_("You don't have a plugin for handling this type of file."));
	}
}
