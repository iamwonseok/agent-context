"""Py-14-02: Use Google style docstrings (PASS)"""


def calculate_discount(price: float, percentage: float) -> float:
    """Calculate the discounted price.

    Applies a percentage discount to the given price and returns
    the final amount after discount.

    Args:
        price: The original price in dollars.
        percentage: The discount percentage (0-100).

    Returns:
        The price after applying the discount.

    Raises:
        ValueError: If price is negative or percentage is out of range.

    Example:
        >>> calculate_discount(100.0, 20)
        80.0
    """
    if price < 0:
        raise ValueError("Price cannot be negative")
    if not 0 <= percentage <= 100:
        raise ValueError("Percentage must be between 0 and 100")
    
    discount = price * (percentage / 100)
    return price - discount


class ShoppingCart:
    """A shopping cart that holds items for purchase.

    Attributes:
        items: List of items in the cart.
        owner: The user who owns this cart.
    """

    def __init__(self, owner: str):
        """Initialize the shopping cart.

        Args:
            owner: The name of the cart owner.
        """
        self.items = []
        self.owner = owner
