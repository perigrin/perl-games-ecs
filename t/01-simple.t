#!/bin/env perl
use strict;
use Test::More;
use Feature::Compat::Class;

use Games::ECS;

class Position :isa(Games::ECS::Component) {
    field $x :param;
    field $y :param;

    method x { $x }
    method y { $y }
}

class Health :isa(Games::ECS::Component) {
    field $max :param;
    field $current :param;
}

class Locator :isa(Games::ECS::System) {
    field $entities_seen_last_update = -1;

    method components_required { ['Position'] }

    method entities_seen_last_update { $entities_seen_last_update }
    method update(@entities) { $entities_seen_last_update = scalar @entities }
}

class Damager :isa(Games::ECS::System) {
    field $entities_seen_last_update = -1;

    method components_required { ['Health'] }
    method entities_seen_last_update { $entities_seen_last_update }
    method update(@entities) { $entities_seen_last_update = scalar @entities }
}

class HealthBarRenderer :isa(Games::ECS::System) {
    field $entities_seen_last_update = -1;

    method components_required { [qw(Position Health)] }
    method entities_seen_last_update { $entities_seen_last_update }
    method update(@entities) { $entities_seen_last_update = scalar @entities }
}

class Destroyer :isa(Games::ECS::System) {
    field $entities_seen_last_update = -1;

    method components_required { ['Health'] }
    method entities_seen_last_update { $entities_seen_last_update }
    method update(@entities) {
        $self->ecs->remove_entity($_) for @entities;
    }
}

my $ecs = Games::ECS->new();

{
    my $e1 = $ecs->add_entity();
    my $p1 = Position->new(x => 5, y => 5);
    $ecs->add_component($e1, $p1);

    ok $ecs->get_components($e1)->has('Position'), 'component adding';
    my $gotP = $ecs->get_components($e1)->get('Position');
    ok $gotP->x == $p1->x && $gotP->y == $p1->y, 'component retrieval';

    $ecs->remove_component($e1, 'Position');
    ok !$ecs->get_components($e1)->has('Position'), 'component deletion';

    my $locator = Locator->new();
    $ecs->add_system($locator);
    $ecs->update();
    is $locator->entities_seen_last_update(), 0, "system doesn't track w/o match";

    $ecs->add_component($e1, $p1);
    $ecs->update();
    is $locator->entities_seen_last_update(), 1, "system does track w/ match";

    $ecs->remove_component($e1, 'Position');
    $ecs->update();
    is $locator->entities_seen_last_update(), 0, "system removes tracking w/o match";

    my $h1 = Health->new(max => 10, current => 10);
    $ecs->add_component($e1, $p1);
    $ecs->add_component($e1, $h1);
    $ecs->update();
    is $locator->entities_seen_last_update(), 1, "system does track w/ superset";

    my $damager = Damager->new();
    $ecs->add_system($damager);
    my $healthBarRenderer = HealthBarRenderer->new();
    $ecs->add_system($healthBarRenderer);
    my $e2 = $ecs->add_entity();
    my $h2 = Health->new(max => 2, current => 2);
    $ecs->add_component($e2, $h2);

    $ecs->update();
    is $locator->entities_seen_last_update(), 1, 'Locator tracking 1 entity';
    is $damager->entities_seen_last_update(), 2, 'Damager tracking 2 entities';
    is $healthBarRenderer->entities_seen_last_update(), 1, 'HealthBarRenderer tracking 1 entity';

    $ecs->remove_system($locator);
    $ecs->remove_system($damager);
    $ecs->remove_system($healthBarRenderer);
    my $destroyer = Destroyer->new();
    $ecs->add_system($destroyer);
    $ecs->add_system($locator);
    $ecs->add_system($damager);
    $ecs->add_system($healthBarRenderer);
    $ecs->update();

    is $locator->entities_seen_last_update, 1, 'locator: entity not removed during update';
    is $damager->entities_seen_last_update, 2, 'damager: entity not remove during update';
    is $healthBarRenderer->entities_seen_last_update, 1, 'healthBarRenderer: entity not removed during update';
    $ecs->update();
    is $locator->entities_seen_last_update, 0, 'locator: entities gone';
    is $damager->entities_seen_last_update, 0, 'damager: entities gone';
    is $healthBarRenderer->entities_seen_last_update, 0, 'healthBarRenderer: entities gone';
}

done_testing;
