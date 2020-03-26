# name the portage image
FROM gentoo/portage:latest as portage

# grab our cat website to host
FROM registry.gitlab.com/alexhaydock/darkwebkittens.xyz as kittens

# image is based on stage3-amd64
FROM gentoo/stage3-amd64:latest

# copy the entire portage volume in
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

# continue with image build ...
RUN emerge nginx

# add nginx.conf
COPY nginx.conf /etc/nginx/nginx.conf

# add kittens into the default nginx www dir for gentoo
COPY --from=kittens /usr/share/nginx/html /var/www/localhost/htdocs

# launch nginx
STOPSIGNAL SIGTERM
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
