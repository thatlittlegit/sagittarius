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

	public class Protocol : Object, UriLoader {
		async IOStream send_request (Upg.Uri uri, Wrapped<HashTable<string,
																	string> > ? cert)
		throws Error {
			var client = new SocketClient ();
			client.set_tls(true);
			client.set_tls_validation_flags(0);

			client.event.connect((event, __, rconn) => {
				if (event != SocketClientEvent.TLS_HANDSHAKING) {
					return;
				}

				var conn = rconn as TlsConnection;
				conn.require_close_notify = false;

				if (cert == null) {
					return;
				}

				var iter = HashTableIter<string, string>(
					cert.unwrap ());
				string path;
				string file = null;
				while (iter.next(out path, out file)) {
					if (uri.to_string_ign(Upg.UriFatalRanking.NONFATAL_NULLABLE)
						 .has_prefix(path)) {
						break;
					}
				}

				if (file != null) {
					try {
						conn.certificate =
							new TlsCertificate.from_file(Filename.from_uri(
								file));
					} catch (Error err) {
						warning("failed to read certificate %s: %s", file,
							err.message);
					}
				}
			});

			var struri = uri.to_string ();
			var conn = yield client.connect_to_uri_async (struri, 1965);

			size_t size;
			yield conn.output_stream.write_all_async (
				"%s\r\n".printf(struri).data, 0, null, out size);

			info("sent request [%ld bytes]".printf((ssize_t) size));

			return conn;
		}

		public async Content fetch (HashTable<string, Object ? > state,
			Upg.Uri uri) throws Error {
			Content ret = {};
			ret.original_uri = uri;

			var ios = yield send_request (uri, (Wrapped<HashTable<string, string> >) state.lookup(
				"$gemini$"));

			var dis = new DataInputStream(ios.input_stream);

			var metaline = dis.read_line ();
			if (metaline.length < 2) {
				throw new IOError.INVALID_DATA("Invalid response (too small)");
			}
			ret.data = (BufferedInputStream) dis;
			ret.__holder = ios;

			metaline.substring(0, 2).scanf("%d", &ret.outcome);
			string meta = metaline.substring(3);

			if (ret.outcome == 20) {
				ret.content_type = GMime.ContentType.parse(
					new GMime.ParserOptions (), meta);
			} else if ((ret.outcome >= 60 && ret.outcome <= 62)) {
				ret.outcome = UriLoadOutcome.SUCCESS;
				ret.content_type = new GMime.ContentType("application",
					"x-gemini-certificate-response");
				ret.content_type.set_parameter("code",
					ret.outcome.to_string ());
			} else {
				ret.content_type = new GMime.ContentType("text", "gemini");
			}

			return ret;
		}
	}
}
