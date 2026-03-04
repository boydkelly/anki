FROM registry.fedoraproject.org/fedora-minimal:44

# Optimize DNF and install core utilities
RUN sed -i '/\[main\]/a tsflags=nodocs' /etc/dnf/dnf.conf && \
  sed -i '/\[main\]/a install_weak_deps=False' /etc/dnf/dnf.conf
# sed -i '/^\[main\]/a proxy=http://192.168.100.101:3128' /etc/dnf/dnf.conf

RUN microdnf install -y \
  python \
  python3-pyqt6 \
  python3-pyqt6-base \
  python3-pyqt6-sip \
  python3-pyqt6-webengine \
  python3-markdown \
  python3-werkzeug \
  python3-blinker \
  python3-click \
  python3-beautifulsoup4 \
  python3-jsonschema \
  python3-waitress \
  python3-orjson \
  python3-itsdangerous \
  python3-typing-extensions \
  python3-requests \
  python3-wrapt \
  python3-send2trash \
  python3-jinja2 \
  qt6-qtwayland \
  python3-decorator && \
  microdnf clean all

WORKDIR /workdir
ENV PATH="/usr/local/anki/bin:$PATH"
ENV ANKI_WAYLAND=1
ENV QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox"
ENV ANKI_BASE="/workdir/Anki2"

COPY anki_start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/anki_start.sh
ENTRYPOINT ["anki_start.sh"]
CMD []
