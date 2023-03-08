use 5.21.0;
use Feature::Compat::Class;

class Games::ECS::Component { }

class Games::ECS::System {
    field $ecs;

    method ecs($new=undef) { $new ? $ecs = $new : $ecs }

    method components_required { [] }
    method update(@entities) { ... }
}

class Games::ECS::ComponentContainer {
    field %map = ();

    method add($component) { $map{ref $component} = $component }

    method has($componentClass) { exists $map{$componentClass} }

    method has_all(@componentClasses) {
        return @componentClasses == grep { exists $map{$_} } @componentClasses;
    }

    method get($componentClass) { return $map{$componentClass} }
    method delete($componentClass) { delete $map{$componentClass} }

}

class Games::ECS::SystemContainer {
    field $system :param;

    field %entities = ();

    method system { $system }

    method add_entity($entity) { $entities{$entity}++ }

    method remove_entity($entity) { delete $entities{$entity} }

    method update { $system->update(keys %entities) }
}

class Games::ECS {
    field $entities = {};
    field %systems = ();

    field $nextEntityID = 9;
    field @entities_to_destroy = ();

    method add_entity() {
        my $e = $nextEntityID++;
        $entities->{$e} = Games::ECS::ComponentContainer->new();
        return $e;
    }

    method remove_entity($entity) {
        push @entities_to_destroy, $entity;
    }

    method get_components($entity) { $entities->{$entity} }

    method add_component($entity, $component) {
        $entities->{$entity}->add($component);
        $self->checkE($entity);
    }

    method remove_component($entity, $componentClass) {
        $entities->{$entity}->delete($componentClass);
        $self->checkE($entity);
    }

    method add_system($system) {
        if ($system->components_required->@* == 0) {
            warn "System ($system) not added: empty required components list";
            return;
        }

        $system->ecs($self);
        $systems{$system} = Games::ECS::SystemContainer->new(system => $system);
        for my $entity (keys %$entities) {
            $self->checkES($entity, $system);
        }
    }

    method remove_system($system) { delete $systems{$system} }

    method update() {
        $_->update() for values %systems;
        $self->destroy_entity($_) for @entities_to_destroy;
    }

    method destroy_entity($entity) {
        delete $entities->{$entity};
        $_->remove_entity($entity) for values %systems;
    }

    method checkE($entity) {
        for my $system (keys %systems) {
            $self->checkES($entity, $systems{$system}->system );
        }
    }

    method checkES($entity, $system) {
        my $have = $entities->{$entity};
        my @need = $system->components_required->@*;
        if ($have->has_all(@need)) {
            $systems{$system}->add_entity($entity);
        } else {
            $systems{$system}->remove_entity($entity);
        }
    }
}
