#!BuildTag: dlp-autoupdate:latest dlp-autoupdate:%PKG_VERSION%
FROM opensuse/tumbleweed

LABEL org.opencontainers.image.title="cpanspec d:l:p autpupdate"
LABEL org.opencontainers.image.version="%PKG_VERSION%.%RELEASE%"
LABEL org.openbuildservice.disturl="%DISTURL%"
LABEL org.opencontainers.image.created="%BUILDTIME%"


RUN zypper install -y -C \
        tar \
        gzip \
        'perl(Algorithm::Diff)' \
        'perl(Archive::Zip)' \
        'perl(Class::Accessor::Chained)' \
        'perl(File::ShareDir::Install)' \
        'perl(LWP::UserAgent)' \
        'perl(Module::Build)' \
        'perl(Module::Build::Tiny)' \
        'perl(Parse::CPAN::Packages)' \
        'perl(Perl::PrereqScanner)' \
        'perl(Pod::POM)' \
        'perl(Text::Autoformat)' \
        'perl(YAML::XS)' \
        'perl(XML::Simple)' \
        obs-service-format_spec_file \
        obs-service-download_files \
        procmail \
        wget \
        osc \
   && zypper clean


