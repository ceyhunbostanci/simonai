FROM squid:6-alpine

# Install dependencies
RUN apk add --no-cache \
    logrotate \
    tzdata

# Create log directory
RUN mkdir -p /var/log/squid && \
    chown -R squid:squid /var/log/squid

# Copy configuration
COPY squid.conf /etc/squid/squid.conf
COPY allowlist.txt /etc/squid/allowlist.txt

# Validate configuration
RUN squid -k parse

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD squid -k check || exit 1

# Expose proxy port
EXPOSE 3128

# Start Squid
CMD ["squid", "-N", "-f", "/etc/squid/squid.conf"]
