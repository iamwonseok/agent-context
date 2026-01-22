"""Py-14-02: Use Google style docstrings (FAIL)"""


def calculate_discount(price: float, percentage: float) -> float:
    # No docstring at all
    if price < 0:
        raise ValueError("Price cannot be negative")
    if not 0 <= percentage <= 100:
        raise ValueError("Percentage must be between 0 and 100")
    
    discount = price * (percentage / 100)
    return price - discount


class ShoppingCart:
    # No class docstring
    
    def __init__(self, owner: str):
        # No method docstring
        self.items = []
        self.owner = owner
    
    def add_item(self, item, quantity):
        # Bad: No parameter documentation
        self.items.append((item, quantity))
    
    def get_total(self):
        # Bad: No return documentation
        return sum(item[1] for item in self.items)
