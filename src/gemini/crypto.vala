/* crypto.vala
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

namespace Sagittarius.Gemini {
	internal enum CryptoCodes {
		CERTIFICATE_WANTED = 60,
		CERTIFICATE_NOT_AUTHORIZED = 61,
		CERTIFICATE_NOT_VALID = 62,
	}

	internal errordomain CryptoError {
		INVALID_OUTCOME,
	}

	public class CryptographyMessageViewer : Object, Sagittarius.Renderer {
		public async RenderingOutcome render (HashTable<string,
														Object ? > state,
			NavigateFunc ? nav,
			Content content) throws Error {
			RenderingOutcome outcome = {};
			ErrorMessage message = new ErrorMessage ();
			outcome.widget = message;
			outcome.title = null;

			int code = 0;
			content.content_type.properties.lookup("code").scanf("%d",
				ref code);

			if (state.lookup("$gemini$") == null) {
				state.insert("$gemini$", new Wrapped<HashTable<string, string> >(
					new HashTable<string, string>(str_hash,
						str_equal)));
			}

			switch ((CryptoCodes) code) {
			case CERTIFICATE_WANTED:
				message.set_message("application-certificate",
					_("Certificate wanted"),
					_(
						"The server is requesting you provide a certificate. You can choose one from the box below."),
					bytes_to_string(yield content.data.read_bytes_async(1024)));

				var filechooser =
					new Gtk.FileChooserButton(_(
						"Choose a certificate..."), Gtk.FileChooserAction.OPEN);
				var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
				box.pack_start(filechooser);
				message.set_prebutton_widget(box);

				filechooser.file_set.connect(() => {
					((Wrapped<HashTable<string, string> >)
					 state.lookup("$gemini$")).unwrap ().insert(content.
						 original_uri.to_string_ign(Upg.UriFatalRanking.
							 NONFATAL_NULLABLE), filechooser.get_uri ());
					nav(content.original_uri);
				});
				break;
			case CERTIFICATE_NOT_VALID:
				message.set_message("dialog-error",
					_("Invalid certificate"),
					_("The certificate you gave isn't valid."));
				break;
			default:
				throw new CryptoError.INVALID_OUTCOME(
					"invalid code given to CryptographyMessageViewer.render: %d",
					content.outcome);
			}

			return outcome;
		}
	}
}
