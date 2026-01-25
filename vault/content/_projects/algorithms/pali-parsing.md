---
title: "Pali Parsing Algorithm"
published: false
draft: false
date: 
license: 
sources: 
images: 
tech: 
description: 
tags:
---

<<<<<<< HEAD
## AI Prompt

I want to transform the lines of pali chanting in an external file by adding rhythmic symbols below the vowels. The line should remain intact in terms of case and punctuation, appart from adding rhythmic mark. Produce a node script that will:

1. Define short vowels, long vowels, vowels, consonants
2. Parse each line of the content
3. Create an array representing the tokens of the line following the rules:
	1. Phonemes should be combined, i.e. d + h = dh, etc. to form one token
		1. For each char of the category HERE, if it is followed by h -> combine them.
	2. For the rest, each characters represent one token, letter as well as punctuation.
4. For each token t, check
	1. t = long vowel -> add a macron under the vowel
	2. t = short vowel -> find the next two tokens (n1 and n2) that are either vowels, consonants or spaces
			1. If n1 = space -> add a breve under the vowel
			2. If n1 = consonant and n2 = vowel -> add a breve under the vowel
			3. If n1 = b and n2 = r -> add a breve under the vowel
			4. Else -> add a macron under the vowel
5. Output all the tokens joined together
6. Repeat for each line.

## AI Prompt 2

I want to transform the lines of pali chanting in an external file by adding rhythmic symbols below the vowels. The line should remain intact in terms of case and punctuation, appart from adding rhythmic mark. Produce a node script that will:

1. Define short vowels, long vowels, vowels, consonants
2. Parse each line of the content
3. Create an array representing the tokens of the line following the rules:
	1. Phonemes should be combined, i.e. d + h = dh, etc. to form one token
	2. For the rest each characters represent one token, letter as well as punctuation.
4. For each token t, check
	1. t = long vowel -> add a macron under the vowel
	2. t = short vowel -> find the next two tokens (n1 and n2) that are either vowels, consonants or spaces
			1. If n1 = consonant and n2 = consonant -> a macron under the vowel
			2. If n1 = consonant and n2 = space -> add a macron under the vowel
			3. Else -> add a breve under the vowel
5. Output all the tokens joined together
6. Repeat for each line.
=======
>>>>>>> origin/master
