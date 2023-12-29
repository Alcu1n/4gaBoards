FROM ghcr.io/rargames/4gaboards:base-latest as server-dependencies

WORKDIR /app

COPY server/package.json server/package-lock.json .

RUN npm install npm@latest --global
RUN npm clean-install --omit=dev --fetch-timeout=60000

FROM node:lts AS client

WORKDIR /app

COPY client/package.json client/package-lock.json .

RUN npm install npm@latest --global
RUN npm clean-install --omit=dev --fetch-timeout=60000

COPY client .
RUN DISABLE_ESLINT_PLUGIN=true npm run build

FROM ghcr.io/rargames/4gaboards:base-latest

RUN apk del vips-dependencies --purge

USER node
WORKDIR /app

COPY --chown=node:node --chmod=775 start.sh .
COPY --chown=node:node server .

RUN mv .env.sample .env

COPY --from=server-dependencies --chown=node:node /app/node_modules node_modules

COPY --from=client --chown=node:node /app/build public
COPY --from=client --chown=node:node /app/build/index.html views/index.ejs

VOLUME /app/public/user-avatars
VOLUME /app/public/project-background-images
VOLUME /app/private/attachments

EXPOSE 1337

CMD ["./start.sh"]
