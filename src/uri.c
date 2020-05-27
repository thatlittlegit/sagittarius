/* uri.c
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

#include <glib.h>
#include <uriparser/Uri.h>

#define S_URI_ERROR s_uri_error_quark ()
G_DEFINE_QUARK(s-uri-error-quark, s_uri_error)

#define UTR_LEN(tr) (tr.afterLast - tr.first)
#define UTR(tr) (tr.first)
#define UTRP(tr) UTR(tr), UTR_LEN(tr)

enum SUriError {
	INVALID_ORIG,
	INVALID_NEW,
	FAILED_JOIN,
	FAILED_NORMALIZE,
	COULDNT_CALCULATE_SIZE,
	MALLOC_FAIL,
	TOSTRING_FAIL,
};

typedef struct {
	gchar * scheme;
} SUri;

gboolean parse_uri_C (gchar * orig, gchar * new_, gchar * * output, GError * * error) {
	const char * errorPos;
	gboolean ret = FALSE;
	gint returned = 0;

	UriUriA orig_uri;
	if ((returned = uriParseSingleUriA(&orig_uri, orig, &errorPos) != URI_SUCCESS)) {
		GError * nerr = g_error_new(S_URI_ERROR, INVALID_ORIG, "failed to parse original URI: %d", returned);
		g_propagate_error(error, nerr);
		goto cleanup1;
	}

	UriUriA new_uri;
	if ((returned = uriParseSingleUriA(&new_uri, new_, &errorPos) != URI_SUCCESS)) {
		GError * nerr = g_error_new(S_URI_ERROR, INVALID_NEW, "failed to parse new URI: %d", returned);
		g_propagate_error(error, nerr);
		goto cleanup2;
	}

	UriUriA new_relative;
	if ((returned = uriAddBaseUriA(&new_relative, &new_uri, &orig_uri) != URI_SUCCESS)) {
		GError * nerr = g_error_new(S_URI_ERROR, FAILED_JOIN, "failed to create new, relative URI: %d", returned);
		g_propagate_error(error, nerr);
		goto cleanup3;
	}

	if (new_relative.pathHead == NULL) {
		UriPathSegmentA * new_head = (UriPathSegmentA *) g_malloc0(sizeof (UriPathSegmentA));
		if (new_head != NULL) {
			gchar * slash = g_strdup("");
			new_head->text = (UriTextRangeA) { slash, slash + 1 };
			new_head->next = NULL;
			new_relative.pathHead = new_relative.pathTail = new_head;
		}
	}

	if ((returned = uriNormalizeSyntaxA(&new_relative)) != URI_SUCCESS) {
		GError * nerr = g_error_new(S_URI_ERROR, FAILED_NORMALIZE, "failed to normalize relative URI: %d", returned);
		g_propagate_error(error, nerr);
		goto cleanup3; // nothing new has been allocated
	}

	gint chars_required;
	if ((returned = uriToStringCharsRequiredA(&new_relative, &chars_required) != URI_SUCCESS)) {
		GError * nerr = g_error_new(S_URI_ERROR, COULDNT_CALCULATE_SIZE, "failed to calculate size of new URI: %d", returned);
		g_propagate_error(error, nerr);
		goto cleanup3; // nothing new has been allocated
	}
	chars_required++;

	gchar * _out;
	if ((_out = g_malloc0(chars_required)) == NULL) {
		// We are out of memory, and are allocating more memory! This is smart
		GError * nerr = g_error_new(S_URI_ERROR, MALLOC_FAIL, "failed to allocate memory for new URI");
		g_propagate_error(error, nerr);
		goto cleanup3; // nothing new has been allocated
	}

	gint chars_written;
	if ((returned = uriToStringA(_out, &new_relative, chars_required, &chars_written) != URI_SUCCESS)) {
		GError * nerr = g_error_new(S_URI_ERROR, TOSTRING_FAIL, "failed to write out new URI: %d", returned);
		g_propagate_error(error, nerr);
		g_free(_out);
		ret = FALSE;
		goto cleanup3;
	}
	g_info("parsed a URL to %s", _out);

	*output = _out;

cleanup3:
	uriFreeUriMembersA(&new_relative);
cleanup2:
	uriFreeUriMembersA(&new_uri);
cleanup1:
	uriFreeUriMembersA(&orig_uri);
	return ret;
}

gboolean parse_uri_to_struct_C (gchar * uri, SUri * ret, GError * * error) {
	UriUriA new_uri;
	gint returned;
	const gchar * errorPos;

	if ((returned = uriParseSingleUriA(&new_uri, uri, &errorPos) != URI_SUCCESS)) {
		GError * nerr = g_error_new(S_URI_ERROR, INVALID_NEW, "failed to parse new URI: %d", returned);
		g_propagate_error(error, nerr);
		return FALSE;
	}

	SUri transformed;
	transformed.scheme = g_strndup(UTRP(new_uri.scheme));

	*ret = transformed;
	return TRUE;
}

gboolean uri_with_query_C (gchar* orig, gchar* query, gchar** out, GError** error) {
  UriUriA uri;
  gint returned;
  gboolean ret = TRUE;
  const gchar* errorPos;

  if ((returned = uriParseSingleUriA (&uri, orig, &errorPos))) {
		GError * nerr = g_error_new(S_URI_ERROR, INVALID_NEW, "failed to parse URI: %d", returned);
		g_propagate_error(error, nerr);
    return FALSE;
  }

  char* copy = g_strdup(query);
  uri.query.first = copy;
  uri.query.afterLast = copy + strlen(copy);

	gint chars_required;
	if ((returned = uriToStringCharsRequiredA(&uri, &chars_required) != URI_SUCCESS)) {
		GError * nerr = g_error_new(S_URI_ERROR, COULDNT_CALCULATE_SIZE, "failed to calculate size of new URI: %d", returned);
		g_propagate_error(error, nerr);
		goto cleanup;
	}
	chars_required++;

	gchar * _out;
	if ((_out = g_malloc0(chars_required)) == NULL) {
		// We are out of memory, and are allocating more memory! This is smart
		GError * nerr = g_error_new(S_URI_ERROR, MALLOC_FAIL, "failed to allocate memory for new URI");
		g_propagate_error(error, nerr);
    ret = FALSE;
		goto cleanup;
	}

	gint chars_written;
	if ((returned = uriToStringA(_out, &uri, chars_required, &chars_written) != URI_SUCCESS)) {
		GError * nerr = g_error_new(S_URI_ERROR, TOSTRING_FAIL, "failed to write out new URI: %d", returned);
		g_propagate_error(error, nerr);
		g_free(_out);
		ret = FALSE;
		goto cleanup;
	}
  g_info("Putting a query string on, got %s", _out);

  *out = _out;

cleanup:
  uriFreeUriMembersA (&uri);
  return ret;
}
