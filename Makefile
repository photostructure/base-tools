.PHONY: update-pins validate

update-pins:
	pinact run -u

validate:
	docker build --target builder -t base-tools:test .
