class Merchant < ApplicationRecord

  validates :name, :updated_at, :created_at, presence: true

  has_many :invoices
  has_many :transactions, through: :invoices
  has_many :invoice_items, through: :invoices
  has_many :items

  def revenue(date)
    invoices.on_date(date)
      .joins(:invoice_items)
      .merge(InvoiceItem.successful)
      .sum('unit_price_in_cents * quantity')
  end

  def self.most_items(quantity)
    joins(:invoice_items)
      .merge(InvoiceItem.successful)
      .group('merchants.id')
      .order('sum(invoice_items.quantity) DESC')
      .take(quantity)
  end

  def self.revenue_by_day(date)
    joins(:invoice_items)
    .merge(Invoice.on_date(date))
    .merge(InvoiceItem.successful)
    .sum('unit_price_in_cents * quantity')
  end

  def customers_with_pending_invoices
    customer_ids = Invoice
      .joins(:transactions)
      .group('invoices.id')
      .having('sum(transactions.result) = 0')
      .where(merchant_id: id)
      .pluck(:customer_id)

    Customer.where(id: customer_ids)
  end
end
