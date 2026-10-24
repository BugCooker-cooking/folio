#!/usr/bin/env python3
"""A small Python sample for Folio."""

from dataclasses import dataclass
from typing import Iterable


@dataclass
class Greeting:
    name: str
    excited: bool = False

    def render(self) -> str:
        suffix = "!" if self.excited else "."
        return f"Hello, {self.name}{suffix}"


def greet(people: Iterable[str]) -> list[str]:
    values = [person.strip() for person in people if person and person.strip()]
    return [Greeting(person, excited=len(person) > 4).render() for person in values]


if __name__ == "__main__":
    print("\n".join(greet(["Ada", "Linus", "Grace"])))
