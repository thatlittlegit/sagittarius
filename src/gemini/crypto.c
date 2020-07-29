/* crypto.c
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
#include <glib.h>
#include <gnutls/x509.h>
#include <gcr/gcr.h>
#include "gemini.h"

static int convert_cert (gpointer, gsize *, gsize, gnutls_x509_crt_fmt_t,
	gnutls_x509_crt_fmt_t);

SagittariusGeminiCertificate * cert_from_file (char * filename) {
	GError * err = NULL;

	GFile * file = g_file_new_for_path(filename);
	GInputStream * stream;
	if ((stream = G_INPUT_STREAM(g_file_read(file, NULL, &err))) == NULL) {
		g_warning("failed to open file %s: %s", filename, err->message);
		g_object_unref(file);
		g_error_free(err);
		return NULL;
	}

	guint read;
	guint8 * buf = g_malloc_n(65535, sizeof (guint8));
	if ((read = g_input_stream_read(stream, buf, 65535, NULL, &err)) < 0) {
		g_warning("failed to read file %s: %s", filename, err->message);
		g_free(buf);
		g_object_unref(stream);
		g_error_free(err);
		return NULL;
	}
	g_object_unref(stream);

	GTlsCertificate * glib;
	if ((glib =
			 g_tls_certificate_new_from_pem((gchar *) buf, -1, &err)) == NULL) {
		g_warning("failed to make GLib certificate for %s: %s", filename,
			err->message);
		g_free(buf);
		g_error_free(err);
		return NULL;
	}

	int retd;
	if ((retd =
			 convert_cert(buf, (gsize *) &read, 65535, GNUTLS_X509_FMT_PEM,
				 GNUTLS_X509_FMT_DER)) < 0) {
		g_warning(
			"failed to convert file %s: GnuTLS error code %d (see its manual for details)", filename,
			retd);
		g_free(buf);
		g_object_unref(glib);
		g_error_free(err);
		return NULL;
	}

	GcrCertificate * gcr;
	if ((gcr = gcr_simple_certificate_new(buf, read)) == NULL) {
		g_warning("failed to make GCR certificate for %s", filename);
		g_free(buf);
		g_object_unref(glib);
		g_error_free(err);
		return NULL;
	}

	g_free(buf);
	return sagittarius_gemini_certificate_new(gcr, glib);
}

GTlsCertificate * gcr_to_glib (GcrCertificate * gcr) {
	if (gcr == NULL) {
		return NULL;
	}

	gsize size;
	guint8 * der = (guint8 *) gcr_certificate_get_der_data(gcr, &size);
	der = g_memdup(der, MAX(size, 65535));

	int retd;
	if ((retd =
			 convert_cert(der, &size, MAX(size, 65535), GNUTLS_X509_FMT_DER,
				 GNUTLS_X509_FMT_PEM))) {
		g_warning("failed to convert certificate (code %d, see GnuTLS manual)",
			retd);
		g_free(der);
		return NULL;
	}

	GError * err = NULL;
	GTlsCertificate * output = g_tls_certificate_new_from_pem((gchar *) der,
		size, &err);
	if (err != NULL) {
		g_warning("failed to make GTlsCertificate: %s", err->message);
		g_error_free(err);
		return NULL;
	}

	return output;
}

static int convert_cert (gpointer data, gsize * size, gsize maxsize,
	gnutls_x509_crt_fmt_t from, gnutls_x509_crt_fmt_t to) {
	gnutls_x509_crt_t certificate;
	gnutls_x509_crt_init(&certificate);

	int retd;
	gnutls_datum_t datum = { data, *size };
	if ((retd = gnutls_x509_crt_import(certificate, &datum, from)) != 0) {
		gnutls_x509_crt_deinit(certificate);
		return retd;
	}

	*size = maxsize;
	if ((retd = gnutls_x509_crt_export(certificate, to, data, size)) != 0) {
		gnutls_x509_crt_deinit(certificate);
		return retd;
	}
	gnutls_x509_crt_deinit(certificate);
	return 0;
}
