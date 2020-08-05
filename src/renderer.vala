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
		public abstract async RenderingOutcome render (HashTable<string,
																 Object ? > state,
			NavigateFunc ? nav,
			Content content,
			Cancellable ? cancel = null) throws
		Error;
	}

	HashTable<string, FeebleRef<Renderer> > renderers = null;

	internal void init_renderers () {
		if (renderers == null) {
			renderers = new HashTable<string, FeebleRef<Renderer> >(str_hash,
				str_equal);
		}
	}

	public void add_renderer (string mime, Renderer renderer) {
		renderers.insert(mime, new FeebleRef<Renderer>(renderer));
	}

	public void remove_renderer (string mime, Renderer renderer) {
		// TODO only remove the right renderer
		renderers.remove(mime);
	}

	public void remove_all_renderers_of_type (Type type) {
		renderers.foreach_remove((entry) => {
			var obj = renderers.lookup(entry).@get ();
			return obj == null || obj.get_type () == type;
		});
	}

	public async RenderingOutcome render_content (HashTable<string,
															Object ? > state,
		NavigateFunc nav,
		Content content, Cancellable ? cancel = null) throws Error {
		var type = content.content_type.to_simple_string ();
		var renderer = renderers.lookup(type);
		message(type);
		if (renderer != null && renderer.@get () != null) {
			return yield renderer.@get ().render(state, nav, content, cancel);
		}

		return open_user_default(content);
	}

	errordomain RenderingError {
		NO_MIME_TYPE,
	}

	RenderingOutcome open_user_default (Content content) throws Error {
		// TODO we need to support writing to a file first
		throw new RenderingError.NO_MIME_TYPE(_(
			"You don't have a plugin for handling this type of file."));
	}
}
