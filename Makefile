# Copyright 2020 Ciena Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

help:
	@echo "see README.md"

step1: secret

step2: pod

step3: logs

step4: modify

step5: logs

step6: added

step7: logs

step8: deleted

step9: logs

step10: clean

original-secret.yml: secret.yml original-secret.txt
	yq r secret.yml -j | jq ".data[\"secret.txt\"]=\"$$(base64 original-secret.txt)\"" |  yq r -P - > original-secret.yml

modified-secret.yml: secret.yml modified-secret.txt
	yq r secret.yml -j | jq ".data[\"secret.txt\"]=\"$$(base64 modified-secret.txt)\"" | yq r -P - > modified-secret.yml

added-secret.yml: modified-secret.yml added-secret.txt
	yq r modified-secret.yml -j | jq ".data[\"added-secret.txt\"]=\"$$(base64 added-secret.txt)\"" | yq r -P - > added-secret.yml

deleted-secret.yml: added-secret.yml
	yq r added-secret.yml -j | jq 'del(.data["secret.txt","added-secret.txt"])' | yq r -P - > deleted-secret.yml

secret: original-secret.yml
	kubectl apply -f ./original-secret.yml

secrets: original-secret.yml modified-secret.yml added-secret.yml

pod:
	kubectl apply -f pod.yml

logs:
	kubectl logs --tail 10 pod/tell-the-secret

follow:
	kubectl logs --tail 10 --follow pod/tell-the-secret

enter:
	kubectl exec -ti pod/tell-the-secret -- ash

modify: modified-secret.yml
	kubectl apply -f ./modified-secret.yml

added: added-secret.yml
	kubectl apply -f ./added-secret.yml

deleted: deleted-secret.yml
	kubectl apply -f ./deleted-secret.yml

clean:
	kubectl delete -f pod.yml || true
	kubectl delete secret the-secret || true
	rm -f original-secret.yml modified-secret.yml added-secret.yml deleted-secret.yml
