#!/usr/bin/env python3
"""
Append a certificate to "trusted" certificate bundles.
"""

import sys
import textwrap


def main():
    cert_file = sys.argv[1]
    system_bundle_file = sys.argv[2]

    with open(cert_file, encoding="utf-8") as fp:
        cert = textwrap.dedent(
            """\

            # SciAuth Environment Self-Signed Certificate
            """
        )
        cert += fp.read()

    with open(system_bundle_file, mode="a", encoding="utf-8") as fp:
        print(cert, file=fp)

    try:
        import certifi

        with open(certifi.where(), mode="a", encoding="utf-8") as fp:
            print(cert, file=fp)
    except ImportError:
        pass


if __name__ == "__main__":
    main()
