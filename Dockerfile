LABEL authors="Henrik Simonsen"
ARG NODE_VERSION="22"
ARG ALPINE_VERSION="3.19"

# Build the project output files
FROM node:${NODE_VERSION} AS BUILD

WORKDIR /tmp

COPY package.json package-lock.json tsconfig.json tsconfig.build.json ./
COPY src src

RUN npm install && \
    npm run build:prod

# Download only dependencies needed for running the application
FROM node:${NODE_VERSION} AS DEPENDENCIES

WORKDIR /tmp

COPY package.json package-lock.json ./
RUN npm install --omit=dev

# Assemble build project and dependencies.
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS ASSEMBLE
# Set environment variable with the port for NESTJS to listen to, defaults to 80 if not set.
ARG PORT=80

ENV PORT=$PORT
WORKDIR /app

COPY --from=DEPENDENCIES /tmp/node_modules/ node_modules
COPY --from=BUILD /tmp/dist dist

EXPOSE ${PORT}/tcp

ENTRYPOINT ["node"]
CMD ["dist/main.js"]

