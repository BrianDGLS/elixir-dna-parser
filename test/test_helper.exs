ExUnit.start()

Application.put_env(:panda, :panda_dataset_small,
  File.read!(Path.join([System.cwd(), "/panda_dna_snippet"]))
)

Application.put_env(:panda, :panda_dataset_large,
  File.read!(Path.join([System.cwd(), "/panda_dna"]))
)
