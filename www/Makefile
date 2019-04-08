www:
	kursg -o out
	./post-process.sh
	chmod a+rX out -R

clean:
	$(RM) -r out
	$(RM) -r manuals
	$(RM) downloads.html

.PHONY: www clean
