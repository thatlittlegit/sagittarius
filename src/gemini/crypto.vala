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
			outcome.title = "Crypto";

			int code = 0;
			content.content_type.get_parameter("code").scanf("%d", ref code);

			switch ((CryptoCodes) code) {
			case CERTIFICATE_WANTED:
				message.set_message("application-certificate",
					_("Certificate wanted"),
					_(
						"The Gemini server wants a certificate. The code to add one is currently missing."));
				break;
			case INVALID_CERTIFICATE:
				message.set_message("dialog-error",
					_("Invalid certificate"),
					_("The certificate you gave isn't valid."));
				break;
			default:
				throw new CryptoError.INVALID_OUTCOME("invalid code %d",
					content.outcome);
			}

			return outcome;
		}
	}
}
