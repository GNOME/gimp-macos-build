"""
GIMP Python SSL Certificate Configuration

Sets SSL_CERT_FILE to use certifi's certificate bundle.
"""

import os
import certifi

# Only set if not already configured by user
if not os.environ.get('SSL_CERT_FILE'):
    os.environ['SSL_CERT_FILE'] = certifi.where()