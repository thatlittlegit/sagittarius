/* history.vala
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
 */

namespace Sagittarius {
	public class History {
		private List<string> queue;
		private int current = -1;

		public List<string> history {
			get {
				return queue;
			}
		}

		public int pos {
			get {
				return current;
			}
			set {
				if (value < queue.length()) {
					current = value;
				}
			}
		}

		public bool can_go_back {
			get {
				return current > 0;
			}
		}

		public bool can_go_forward {
			get {
				return current + 1 < queue.length();
			}
		}

		public void back() {
			current--;
		}

		public void forward() {
			if (current + 1 < queue.length()) {
				current++;
			}
		}

		public string top() {
			return queue.nth_data(current);
		}

		public void navigate(string full_uri) {
			remove_all_after(current);
			current++;
			queue.append(full_uri);
		}

		private void remove_all_after(int current) {
			while (current + 1 < queue.length ()) {
				queue.remove_link(queue.last());
			}
		}
	}
}
