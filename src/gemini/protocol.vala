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
		async ByteArray send_request (Upg.Uri uri, Wrapped<HashTable<string,
																	 string> > ? cert)
		throws Error {
			var client = new SocketClient ();
			client.set_tls(true);
			client.set_tls_validation_flags(0);

			client.event.connect((event, __, rconn) => {
				if (event != SocketClientEvent.TLS_HANDSHAKING || cert == null) {
					return;
				}

				var conn = rconn as TlsConnection;
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

			return yield slurp (conn.input_stream);
		}

		private int find_status (ByteArray bytearray) {
			var ret = ((bytearray.data[0] - 0x30) * 10)
					  + (bytearray.data[1] - 0x30);
			bytearray.remove_range(0, 2);
			return ret;
		}

		private string find_meta (ByteArray bytearray) {
			int i;
			StringBuilder meta =
				new StringBuilder.sized(bytearray.len.clamp(0, 1024));
			for (i = 0; i < bytearray.len && i < 1024; i++) {
				char current = (char) bytearray.data[i];

				if (current == '\r') {
					i++;
					break;
				}

				if (current == '\n') {
					// invalid, but we'll let it slide 'cause it's a lot better
					break;
				}

				meta.append_c(current);
			}
			bytearray.remove_range(0, i + 1);

			return meta.str.strip ();
		}

		public async Content fetch (HashTable<string, Object ? > state,
			Upg.Uri uri) throws Error {
			Content ret = {};
			ret.original_uri = uri;

			var array = yield send_request (uri, (Wrapped<HashTable<string, string> >) state.lookup(
				"$gemini$"));

			if (array.len < 2) {
				throw new IOError.INVALID_DATA("Invalid response (too small)");
			}
			info("recieved %ld bytes of content".printf(array.len));

			var status = find_status(array);
			ret.outcome = (UriLoadOutcome) status;
			var meta = find_meta(array);
			array.append({ 0 });

			if (status == 20) {
				ret.content_type = GMime.ContentType.parse(
					new GMime.ParserOptions (), meta);
				ret.data = ByteArray.free_to_bytes(array);
				return ret;
			}

			if ((status >= 60 && status <= 62)) {
				ret.outcome = UriLoadOutcome.SUCCESS;
				ret.content_type = new GMime.ContentType("application",
					"x-gemini-certificate-response");
				ret.content_type.set_parameter("code", status.to_string ());
			} else {
				ret.content_type = new GMime.ContentType("text", "gemini");
			}

			ret.data = new Bytes.take(meta.data);
			return ret;
		}
	}
}
