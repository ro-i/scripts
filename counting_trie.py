#!/usr/bin/env python3

import argparse
import ast
from itertools import islice
from typing import Any


type Seq = list[Any]


class CountingTrie:
    def __init__(self, elem: Any) -> None:
        self.elem: Any = elem  # None for root
        self.count: int = 0
        self.max_index: int = -1
        self.len: int = -1
        self.children: dict[Any, CountingTrie] = {}

    def __repr__(self) -> str:
        stack: list[tuple[CountingTrie, int]] = [(self, 0)]
        ret: str = ""

        while stack:
            current, indent = stack.pop()
            ret += (
                " " * indent
                + f"{{elem: {current.elem}; count: {current.count}; max_index: {current.max_index}}}\n"
            )
            stack.extend((child, indent + 4) for child in current.children.values())

        return ret

    def get_sequences(self, min_count: int = 1) -> list[tuple[int, Seq]]:
        stack: list[tuple[CountingTrie, Seq]] = [
            (child, []) for child in self.children.values()
        ]
        seqs: list[tuple[int, Seq]] = []

        while stack:
            current, seq = stack.pop()
            seq.append(current.elem)
            # Note that the count of the children is <= the count of the parent.
            # So there is no need to look at the children if the parent's count
            # does not even fit.
            if current.count >= min_count:
                seqs.append((current.count, seq))
                stack.extend((child, seq.copy()) for child in current.children.values())

        return seqs

    def _insert(self, seq: Seq, index: int) -> None:
        current: CountingTrie = self
        start_index: int = index

        for elem in islice(seq, index, None):
            if elem not in current.children:
                current.children[elem] = CountingTrie(elem)
            current = current.children[elem]
            current_len: int = index - start_index
            if current_len <= current.len and start_index > current.max_index:
                current.count += 1
                current.max_index = index
            elif current_len > current.len:
                current.count += 1
                current.max_index = index
                current.len = current_len

            index += 1

    def insert(self, seq: Seq) -> None:
        if not seq:
            return

        for i in range(len(seq)):
            self._insert(seq, i)

    def print(self, min_count: int = 1) -> None:
        self.print_sequences(self.get_sequences(min_count=min_count))

    def print_sequences(self, seqs: list[tuple[int, Seq]]) -> None:
        print(
            "\n".join(
                f"{num}\t{', '.join(map(str, seq))}"
                for num, seq in sorted(seqs, key=lambda k: k[1])
            )
        )


def analyze(seq: Seq, return_result: bool = False) -> list[tuple[int, Seq]] | None:
    trie: CountingTrie = CountingTrie(None)

    trie.insert(seq)

    seqs: list[tuple[int, Seq]] = trie.get_sequences(min_count=2)
    trie.print_sequences(seqs)

    if return_result:
        return seqs

    return


def check(seq: Seq, seqs: list[tuple[int, Seq]]) -> None:
    def count_subsequence(subseq: Seq) -> int:
        count: int = 0
        i: int = 0
        while i < len(seq):
            if seq[i : i + len(subseq)] == subseq:
                count += 1
                i += len(subseq)
            else:
                i += 1
        return count

    print("\n==== CHECK BEGIN ====\n")

    for count, subseq in seqs:
        c: int = count_subsequence(subseq)
        if c != count:
            print(f"{c} instead of {count} occurrences of {subseq}")

    print("\n==== CHECK END ====\n")


def parse_file(filename: str) -> Seq:
    with open(filename) as file:
        content: str = file.read()
    seq: Any = ast.literal_eval(content)
    if not isinstance(seq, list):
        raise TypeError(f"{type(seq)} is not a subclass of list")
    return seq


def test(num_elem: int, length: int) -> list[int]:
    from random import choices

    seq: list[int] = choices(range(num_elem), k=length)
    print(f"generated: {', '.join(map(str, seq))}")

    return seq


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "file", nargs="?", help="file containing the textual representation of a list"
    )
    parser.add_argument("-c", "--check", action="store_true", help="check result")
    parser.add_argument("-s", "--sequence", type=int, nargs="+", help="test sequence")
    parser.add_argument("-t", "--test", type=int, nargs=2, help="test implementation")
    args = parser.parse_args()

    seq: Seq
    if args.sequence:
        seq = args.sequence
    elif args.test:
        seq = test(*args.test)
    elif args.file:
        seq = parse_file(args.file)
    else:
        raise ValueError("neither test nor file specified")

    result: list[tuple[int, Seq]] | None = analyze(seq, return_result=args.check)

    if args.check and result:
        check(seq, result)


if __name__ == "__main__":
    main()
