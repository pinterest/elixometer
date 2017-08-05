# Exclude Elixir 1.5-tagged tests when running on earlier versions.
if Version.compare(System.version(), "1.5.0-rc") == :lt do
  ExUnit.configure(exclude: [elixir: 1.5])
end

ExUnit.start()
