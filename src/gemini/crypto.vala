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
		private List<Certificate> certificates;

		construct {
			certificates = new List<Certificate>();
		}

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
						"The server is requesting you provide a certificate. You can choose one from the box below."),
					bytes_to_string(content.data));

				var chooser = new Gcr.ComboSelector(gcr_certs ());
				chooser.changed.connect(() => message.button.sensitive = true);

				message.button.label = _("Go");
				message.button.sensitive = false;
				message.button.clicked.connect(() => {
					var table =
						((Wrapped<HashTable<string, Certificate> >)state.lookup(
							"$gemini$")).unwrap () ??
						new HashTable<string, Certificate>(str_hash,
							str_equal);
					table.insert(content.original_uri.to_string (),
						from_index(chooser.get_selected ().get_data<int>("i")));
					state.replace("$gemini$",
						(Object ? ) new Wrapped<HashTable<string,
														  Certificate> >(
							table));
					nav(content.original_uri);
				});

				var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
				box.pack_start(chooser);
				message.set_prebutton_widget(box);
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

		private Gcr.Collection gcr_certs () {
			var gcr = new Gcr.SimpleCollection ();
			int i = 0;
			foreach (var cert in certificates) {
				cert.gcr.set_data<int>("i", i++);
				gcr.add(cert.gcr);
			}

			return gcr;
		}

		private Certificate from_index (int index) {
			return certificates.nth_data(index);
		}

		public void add_certificate (string filename) {
			certificates.prepend(cert_from_file(filename));
		}

		[CCode(cname = "cert_from_file")]
		private extern static Certificate cert_from_file (string filename);
	}

	[CCode(cname = "gcr_to_glib")]
	internal extern static TlsCertificate gcr_to_glib (Gcr.Certificate cert);

	public class Certificate {
		public Gcr.Certificate gcr;
		public TlsCertificate glib;

		public Certificate (Gcr.Certificate gcr, TlsCertificate glib) {
			this.gcr = gcr;
			this.glib = glib;
		}
	}
}
