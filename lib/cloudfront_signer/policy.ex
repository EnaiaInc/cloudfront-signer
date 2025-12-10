defmodule CloudfrontSigner.Policy do
  @moduledoc """
  Defines a cloudfront signature policy, and a string coercion method for it
  """
  defstruct [:resource, :expiry]

  @type t :: %__MODULE__{}

  defimpl String.Chars, for: CloudfrontSigner.Policy do
    @doc """
    Generates a JSON policy string with deterministic key ordering.

    AWS CloudFront requires the exact JSON format specified in their documentation:
    https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-creating-signed-url-canned-policy.html

    The key order MUST be: Statement -> Resource -> Condition -> DateLessThan -> AWS:EpochTime

    This is critical because CloudFront validates the signature against the exact
    JSON string. Map key ordering in Elixir/OTP is non-deterministic, so we must
    use Jason.OrderedObject to ensure consistent key ordering across all environments.
    """
    def to_string(%{resource: resource, expiry: expiry}) do
      # Build the policy with explicit key ordering matching AWS documentation.
      # Using Jason.OrderedObject preserves insertion order during JSON encoding.
      Jason.OrderedObject.new([
        {"Statement", [
          Jason.OrderedObject.new([
            {"Resource", resource},
            {"Condition", Jason.OrderedObject.new([
              {"DateLessThan", Jason.OrderedObject.new([
                {"AWS:EpochTime", expiry}
              ])}
            ])}
          ])
        ]}
      ])
      |> Jason.encode!()
    end
  end
end
