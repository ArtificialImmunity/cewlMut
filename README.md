# cewlMut
A tool to generate an extensive wordlist specific to a particular URL (Uses CeLW, John, and, RSMangler)

Usage:

	cewlMut [OPTION] ... URL
		-d: depth of CeWL spider, default 2
		-m: minimum word length, default 6
		-x: maximum word length, default 12
		-o: specify the name of the output directory, default CeWLMutOutput
	

Example:

<code>./cewlMut.sh -o mywebsite \<URL\></code>
	
