#! /usr/bin/env bash

# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# shellcheck source=istio.env

set -e

STARS="${1}"

source istio.env

# Get the IP address and port of the cluster's gateway to run tests against
INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway \
  -o jsonpath='{.spec.ports[?(@.name=="http")].port}')

# Get and store the currently served webpage
FIVE_STAR="$(curl -s http://"${INGRESS_HOST}:${INGRESS_PORT}"/productpage)"

# Update the MySQL database rating with a one star review to generate a diff
# proving the MySQL on GCE database is being used by the application
"${PWD}/update-db-ratings.sh" "${GCE_PROJECT}" "${ZONE}" "${GCE_VM}" "${STARS}"

# Get the updated webpage with the updated ratings
ONE_STAR="$(curl -s http://"${INGRESS_HOST}:${INGRESS_PORT}"/productpage)"

# Check to make sure that changing the rating in the DB generated a diff in the
# webpage
diff --suppress-common-lines <(echo "${ONE_STAR}") <(echo "${FIVE_STAR}")

exit 0
