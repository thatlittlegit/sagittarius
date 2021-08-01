/* proto-gemini.vala
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
	errordomain GeminiError {
		UNKNOWN_RESPONSE_CODE,
		INVALID_ENCODING,
		INVALID_RESPONSE,
	}

	internal class Certificate {
		public Upg.Uri uri;
		public File file;

		public Certificate (Upg.Uri uri, File file) {
			this.uri = uri;
			this.file = file;
		}
	}

	public class Protocol : Object, UriLoader {
		internal static unowned List<Certificate> current_certificates { get; internal set; }

		private async IOStream send_request (Upg.Uri uri, File ? cert, Cancellable ? cancel) throws Error {
			var client = new SocketClient ();
			client.set_tls(true);
			client.set_tls_validation_flags(0);

			client.event.connect((event, __, rconn) => {
				if (event != SocketClientEvent.TLS_HANDSHAKING) {
					return;
				}

				var conn = rconn as TlsConnection;
				conn.require_close_notify = false;

				string ? path = null;
				if (cert == null || (path = cert.get_path ()) == null) {
					return;
				}

				try {
					conn.certificate = new TlsCertificate.from_file(path);
				} catch (Error err) {
					warning("failed to read certificate %s: %s", path, err.message);
				}
			});

			var struri = uri.to_string ();
			var conn = yield client.connect_to_uri_async (struri, 1965, cancel);

			size_t size;
			yield conn.output_stream.write_all_async ("%s\r\n".printf(struri).data, 0, cancel, out size);

			info("sent request [%ld bytes]".printf((ssize_t) size));

			return conn;
		}

		public async Content fetch (Upg.Uri uri, Cancellable ? cancel) throws Error {
			Content ret = {};
			ret.original_uri = uri;

			File ? certificate_file = null;
			foreach (var cert in current_certificates) {
				message("%s vs. %s", cert.uri.to_string (), uri.to_string ());
				if (cert.uri.is_parent_of(uri, 1965, Upg.HierarchyFlags.LAX)) {
					certificate_file = cert.file;
					break;
				}
			}

			var ios = yield send_request (uri, certificate_file, cancel);

			var dis = new DataInputStream(ios.input_stream);
			dis.newline_type = DataStreamNewlineType.ANY;

			size_t size;
			var metaline = yield dis.read_line_utf8_async (100, cancel,
				out size);

			if (size < 2) {
				throw new IOError.INVALID_DATA("Invalid response (too small)");
			}
			ret.data = (BufferedInputStream) dis;
			ret.__holder = ios;

			metaline.substring(0, 2).scanf("%d", &ret.outcome);
			string meta = metaline.substring(3);

			if (ret.outcome == 20) {
				ret.content_type = new ContentType.parse(meta);
			} else if ((ret.outcome >= 60 && ret.outcome <= 62)) {
				ret.content_type = new ContentType("application",
					"x-gemini-certificate-response");
				ret.content_type.properties.insert("code",
					((uint) ret.outcome).to_string ());
				ret.outcome = UriLoadOutcome.SUCCESS;
			} else {
				ret.content_type = new ContentType("text", "gemini");
				ret.data = new MemoryInputStream.from_data(meta.data);
			}

			return ret;
		}
	}
}
